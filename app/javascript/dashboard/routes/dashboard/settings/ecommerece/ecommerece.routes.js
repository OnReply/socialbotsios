import SettingsContent from '../Wrapper';
import EcommereceHome from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/ecommerece'),
      component: SettingsContent,
      props: {
        headerTitle: 'ECOMMERECE.HEADER',
        icon: 'cart',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'ecommerece_wrapper',
          redirect: 'dashboard',
        },
        {
          path: 'dashboard',
          name: 'ecommerece',
          roles: ['administrator'],
          component: EcommereceHome,
        },
      ],
    },
  ],
};